import AcmePlatform
import Foundation
import Testing

@Suite struct KitFlagsTests {
    @Test func honorsAllowLists() throws {
        let registry = Kit.Flags.newRegistry()
        registry.register(Kit.Flags.Flag(
            name: "beta",
            enabled: true,
            strategy: Kit.Flags.AllowListStrategy(subjects: ["tenant-a"])
        ))
        #expect(registry.enabled("beta", subject: "tenant-a"))
        #expect(!registry.enabled("beta", subject: "tenant-b"))
        #expect(!registry.enabled("missing", subject: "tenant-a"))
    }
}
