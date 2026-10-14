@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionClaimStore = Labs.newMemoryAccessionClaimStore()
        let item = Labs.newAccessionClaim("code-131", name: "name-296")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
