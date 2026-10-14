@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySeasonalSkillMixSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SeasonalSkillMixSegmentStore = Staffing.newMemorySeasonalSkillMixSegmentStore()
        let item = Staffing.newSeasonalSkillMixSegment("code-158", name: "name-20")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
