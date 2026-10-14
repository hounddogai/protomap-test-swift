@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyCycleStore = Imaging.newMemoryStudyCycleStore()
        let item = Imaging.newStudyCycle("code-988", label: "label-288")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
