@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimarySkillMixScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimarySkillMixScoreStore = Staffing.newMemoryPrimarySkillMixScoreStore()
        let item = Staffing.newPrimarySkillMixScore("code-692", name: "name-555")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
