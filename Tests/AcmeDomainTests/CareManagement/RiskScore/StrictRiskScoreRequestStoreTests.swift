@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryStrictRiskScoreRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.StrictRiskScoreRequestStore = CareManagement.newMemoryStrictRiskScoreRequestStore()
        let item = CareManagement.newStrictRiskScoreRequest("code-195", name: "name-209")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
