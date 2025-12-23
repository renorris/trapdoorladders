using System;
using HarmonyLib;
using Vintagestory.API.Common;
using Vintagestory.API.Common.Entities;
using Vintagestory.API.MathTools;
using Vintagestory.GameContent;

namespace TrapdoorLadders
{
    public class TrapdoorLaddersSystem : ModSystem
    {
        private Harmony? harmony;
        public static ICoreAPI? Api { get; private set; }

        public override void Start(ICoreAPI api)
        {
            base.Start(api);
            Api = api;
            
            harmony = new Harmony("com.trapdoorladders.patches");
            harmony.PatchAll();
            
            api.Logger.Notification("Trapdoor Ladders: Harmony patches applied for climbable trapdoors.");
        }

        public override void Dispose()
        {
            harmony?.UnpatchAll("com.trapdoorladders.patches");
            Api = null;
            base.Dispose();
        }
    }

    /// <summary>
    /// Helper class to check if a block at a position is an open trapdoor adjacent to a ladder
    /// </summary>
    public static class TrapdoorClimbHelper
    {
        /// <summary>
        /// Checks if a block is a ladder (not a trapdoor, not just any climbable block).
        /// This prevents recursion and ensures only trapdoors directly next to ladders are climbable.
        /// </summary>
        private static bool IsLadderBlock(Block? block)
        {
            if (block == null) return false;
            
            string? code = block.Code?.Path;
            if (string.IsNullOrEmpty(code)) return false;
            
            // Exclude trapdoors to prevent recursion
            if (code.Contains("trapdoor")) return false;
            
            // Check if it's a ladder (wood ladder, rope ladder, etc.)
            return code.Contains("ladder") && block.Climbable;
        }

        /// <summary>
        /// Checks if a block is an open trapdoor that is directly adjacent to a ladder.
        /// Only returns true for trapdoors with a ladder directly above or below.
        /// No chaining - trapdoor next to trapdoor doesn't count.
        /// </summary>
        public static bool IsOpenTrapdoorWithLadder(IWorldAccessor? world, Block? block, BlockPos? pos)
        {
            if (world == null || block == null || pos == null) return false;
            
            try
            {
                string? code = block.Code?.Path;
                if (string.IsNullOrEmpty(code) || !code.Contains("trapdoor"))
                {
                    return false;
                }

                var blockAccessor = world.BlockAccessor;
                if (blockAccessor == null) return false;
                
                var blockEntity = blockAccessor.GetBlockEntity(pos);
                if (blockEntity == null) return false;

                var bebTrapDoor = blockEntity.GetBehavior<BEBehaviorTrapDoor>();
                if (bebTrapDoor == null || !bebTrapDoor.Opened) return false;

                // Check for LADDER (not just any climbable) above or below
                var posAbove = pos.UpCopy();
                var blockAbove = blockAccessor.GetBlock(posAbove);
                if (IsLadderBlock(blockAbove)) return true;

                var posBelow = pos.DownCopy();
                var blockBelow = blockAccessor.GetBlock(posBelow);
                if (IsLadderBlock(blockBelow)) return true;

                return false;
            }
            catch
            {
                return false;
            }
        }
    }

    /// <summary>
    /// Harmony patch to make trapdoors report as climbable when open and adjacent to a ladder
    /// </summary>
    [HarmonyPatch(typeof(Block), nameof(Block.IsClimbable))]
    public static class Block_IsClimbable_Patch
    {
        public static void Postfix(Block __instance, BlockPos pos, ref bool __result)
        {
            if (__result) return;

            try
            {
                var world = TrapdoorLaddersSystem.Api?.World;
                if (world == null) return;

                if (TrapdoorClimbHelper.IsOpenTrapdoorWithLadder(world, __instance, pos))
                {
                    __result = true;
                }
            }
            catch
            {
                // Silently ignore exceptions to prevent game crashes
            }
        }
    }

    /// <summary>
    /// Harmony patch to apply climbing motion when inside an open trapdoor
    /// </summary>
    [HarmonyPatch(typeof(Block), nameof(Block.OnEntityInside))]
    public static class Block_OnEntityInside_Patch
    {
        public static void Postfix(Block __instance, IWorldAccessor world, Entity entity, BlockPos pos)
        {
            try
            {
                if (entity?.Properties?.CanClimb != true) return;
                if (entity is not EntityAgent agent) return;

                if (!TrapdoorClimbHelper.IsOpenTrapdoorWithLadder(world, __instance, pos)) return;

                bool wantsToClimb = agent.Controls.Forward || agent.Controls.Backward || 
                                    agent.Controls.Jump || agent.Controls.Up;
                bool wantsToDescend = agent.Controls.Sneak;

                if (wantsToDescend)
                {
                    if (agent.SidedPos.Motion.Y < 0)
                    {
                        agent.SidedPos.Motion.Y = 0;
                    }
                }
                else if (wantsToClimb)
                {
                    agent.SidedPos.Motion.Y = 0.04;
                }
                else
                {
                    if (agent.SidedPos.Motion.Y < 0)
                    {
                        agent.SidedPos.Motion.Y = 0;
                    }
                }
            }
            catch
            {
                // Silently ignore exceptions to prevent game crashes
            }
        }
    }
}
