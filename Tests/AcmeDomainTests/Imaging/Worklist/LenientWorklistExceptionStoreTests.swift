@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientWorklistExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientWorklistExceptionStore = Imaging.newMemoryLenientWorklistExceptionStore()
        let item = Imaging.newLenientWorklistException("code-169", title: "title-249")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
