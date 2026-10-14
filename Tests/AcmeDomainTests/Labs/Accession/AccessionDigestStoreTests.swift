@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionDigestStore = Labs.newMemoryAccessionDigestStore()
        let item = Labs.newAccessionDigest("code-631", title: "title-523")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
