@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRegionalSkillMixLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RegionalSkillMixLedgerStore = Staffing.newMemoryRegionalSkillMixLedgerStore()
        let item = Staffing.newRegionalSkillMixLedger("code-139", title: "title-707")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
