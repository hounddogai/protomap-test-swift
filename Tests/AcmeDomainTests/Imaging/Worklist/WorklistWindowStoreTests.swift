@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistWindowStore = Imaging.newMemoryWorklistWindowStore()
        let item = Imaging.newWorklistWindow("code-473", title: "title-104")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
