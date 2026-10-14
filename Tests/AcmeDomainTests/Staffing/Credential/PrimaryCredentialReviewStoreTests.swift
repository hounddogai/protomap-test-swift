@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryPrimaryCredentialReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.PrimaryCredentialReviewStore = Staffing.newMemoryPrimaryCredentialReviewStore()
        let item = Staffing.newPrimaryCredentialReview("code-701", label: "label-832")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
