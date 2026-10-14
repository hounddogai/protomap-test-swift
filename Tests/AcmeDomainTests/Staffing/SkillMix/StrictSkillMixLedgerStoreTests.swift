@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictSkillMixLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictSkillMixLedgerStore = Staffing.newMemoryStrictSkillMixLedgerStore()
        let item = Staffing.newStrictSkillMixLedger("code-679", name: "name-382")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
