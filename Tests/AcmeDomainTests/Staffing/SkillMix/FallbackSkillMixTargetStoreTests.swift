@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackSkillMixTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackSkillMixTargetStore = Staffing.newMemoryFallbackSkillMixTargetStore()
        let item = Staffing.newFallbackSkillMixTarget("code-872", title: "title-891")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
