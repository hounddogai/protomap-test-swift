@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryScheduledHandoffWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.ScheduledHandoffWindowStore = ClinicalOps.newMemoryScheduledHandoffWindowStore()
        let item = ClinicalOps.newScheduledHandoffWindow("code-818", label: "label-367")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
