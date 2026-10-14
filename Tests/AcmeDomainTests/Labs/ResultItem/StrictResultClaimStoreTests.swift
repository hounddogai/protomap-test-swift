@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryStrictResultClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.StrictResultClaimStore = Labs.newMemoryStrictResultClaimStore()
        let item = Labs.newStrictResultClaim("code-682", name: "name-71")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
