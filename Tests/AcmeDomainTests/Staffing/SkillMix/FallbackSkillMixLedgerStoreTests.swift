@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackSkillMixLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackSkillMixLedgerStore = Staffing.newMemoryFallbackSkillMixLedgerStore()
        let item = Staffing.newFallbackSkillMixLedger("code-66", label: "label-750")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
