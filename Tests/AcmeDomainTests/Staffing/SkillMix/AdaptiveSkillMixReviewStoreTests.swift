@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAdaptiveSkillMixReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AdaptiveSkillMixReviewStore = Staffing.newMemoryAdaptiveSkillMixReviewStore()
        let item = Staffing.newAdaptiveSkillMixReview("code-388", label: "label-74")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
