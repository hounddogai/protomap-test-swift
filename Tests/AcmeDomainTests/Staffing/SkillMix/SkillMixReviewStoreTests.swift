@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemorySkillMixReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.SkillMixReviewStore = Staffing.newMemorySkillMixReviewStore()
        let item = Staffing.newSkillMixReview("code-963", name: "name-626")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
