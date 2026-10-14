@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedCareGapWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedCareGapWindowStore = CareManagement.newMemoryWeightedCareGapWindowStore()
        let item = CareManagement.newWeightedCareGapWindow("code-731", label: "label-294")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
