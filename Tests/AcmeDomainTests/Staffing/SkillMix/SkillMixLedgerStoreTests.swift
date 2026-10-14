@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixLedgerStore = Staffing.newMemorySkillMixLedgerStore()
        let item = Staffing.newSkillMixLedger("code-703", label: "label-633")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
