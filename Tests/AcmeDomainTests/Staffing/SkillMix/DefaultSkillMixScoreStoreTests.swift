@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryDefaultSkillMixScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.DefaultSkillMixScoreStore = Staffing.newMemoryDefaultSkillMixScoreStore()
        let item = Staffing.newDefaultSkillMixScore("code-644", title: "title-260")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
