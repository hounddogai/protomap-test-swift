@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryScheduledFloatPoolReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ScheduledFloatPoolReviewStore = Staffing.newMemoryScheduledFloatPoolReviewStore()
        let item = Staffing.newScheduledFloatPoolReview("code-108", title: "title-694")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
