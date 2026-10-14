@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictSkillMixReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictSkillMixReviewStore = Staffing.newMemoryStrictSkillMixReviewStore()
        let item = Staffing.newStrictSkillMixReview("code-418", name: "name-653")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
