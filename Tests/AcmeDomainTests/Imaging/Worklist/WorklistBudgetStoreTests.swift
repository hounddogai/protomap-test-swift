@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistBudgetStore = Imaging.newMemoryWorklistBudgetStore()
        let item = Imaging.newWorklistBudget("code-339", label: "label-603")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
