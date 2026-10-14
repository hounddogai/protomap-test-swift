@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackCourierExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackCourierExceptionStore = Labs.newMemoryFallbackCourierExceptionStore()
        let item = Labs.newFallbackCourierException("code-86", title: "title-965")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
