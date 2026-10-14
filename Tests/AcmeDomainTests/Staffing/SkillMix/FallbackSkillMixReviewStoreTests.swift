@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackSkillMixReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackSkillMixReviewStore = Staffing.newMemoryFallbackSkillMixReviewStore()
        let item = Staffing.newFallbackSkillMixReview("code-650", name: "name-376")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
