@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramReviewStore = CareManagement.newMemoryProgramReviewStore()
        let item = CareManagement.newProgramReview("code-568", name: "name-897")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
