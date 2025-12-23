using Vintagestory.API.Common;
using Vintagestory.API.Server;

namespace TrapdoorLadders
{
    /// <summary>
    /// Main mod system for Trapdoor Ladder Mod
    /// </summary>
    public class TrapdoorLaddersSystem : ModSystem
    {
        public override void Start(ICoreAPI api)
        {
            base.Start(api);
            api.Logger.Notification("Trapdoor Ladder Mod loaded successfully!");
        }

        public override void StartServerSide(ICoreServerAPI api)
        {
            base.StartServerSide(api);
            api.Logger.Notification("Trapdoor Ladder Mod: Server-side initialization complete.");
        }
    }
}

