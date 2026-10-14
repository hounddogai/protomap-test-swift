@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadExceptionStore = Imaging.newMemoryReadExceptionStore()
        let item = Imaging.newReadException("code-536", label: "label-559")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
