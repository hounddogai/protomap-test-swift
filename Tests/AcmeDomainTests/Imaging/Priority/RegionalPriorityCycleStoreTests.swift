@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalPriorityCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalPriorityCycleStore = Imaging.newMemoryRegionalPriorityCycleStore()
        let item = Imaging.newRegionalPriorityCycle("code-556", label: "label-160")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
