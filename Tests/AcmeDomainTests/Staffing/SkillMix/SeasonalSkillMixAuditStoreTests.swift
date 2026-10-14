@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySeasonalSkillMixAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SeasonalSkillMixAuditStore = Staffing.newMemorySeasonalSkillMixAuditStore()
        let item = Staffing.newSeasonalSkillMixAudit("code-884", title: "title-806")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
