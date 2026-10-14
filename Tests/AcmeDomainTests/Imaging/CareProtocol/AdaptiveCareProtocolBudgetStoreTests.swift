@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptiveCareProtocolBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptiveCareProtocolBudgetStore = Imaging.newMemoryAdaptiveCareProtocolBudgetStore()
        let item = Imaging.newAdaptiveCareProtocolBudget("code-804", label: "label-604")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
