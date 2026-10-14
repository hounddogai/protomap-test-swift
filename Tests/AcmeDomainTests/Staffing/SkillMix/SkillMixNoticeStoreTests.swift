@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixNoticeStore = Staffing.newMemorySkillMixNoticeStore()
        let item = Staffing.newSkillMixNotice("code-56", name: "name-376")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
