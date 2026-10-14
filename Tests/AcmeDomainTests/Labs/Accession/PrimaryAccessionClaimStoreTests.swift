@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPrimaryAccessionClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PrimaryAccessionClaimStore = Labs.newMemoryPrimaryAccessionClaimStore()
        let item = Labs.newPrimaryAccessionClaim("code-884", name: "name-50")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
