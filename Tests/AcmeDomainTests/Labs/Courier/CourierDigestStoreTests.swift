@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierDigestStore = Labs.newMemoryCourierDigestStore()
        let item = Labs.newCourierDigest("code-686", label: "label-238")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
