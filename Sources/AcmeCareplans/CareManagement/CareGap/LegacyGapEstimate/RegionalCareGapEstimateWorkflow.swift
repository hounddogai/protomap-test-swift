import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves regional care gap estimates through their life cycle and keeps a journal of what it did.
    final class RegionalCareGapEstimateService {
        var store: any RegionalCareGapEstimateStore
        var validator: RegionalCareGapEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalCareGapEstimateStore, validator: RegionalCareGapEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional care gap estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalCareGapEstimateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional care gap estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalCareGapEstimateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newRegionalCareGapEstimateService(_ store: any RegionalCareGapEstimateStore, clock: any Kit.Clocks.Clock) -> RegionalCareGapEstimateService {
        return RegionalCareGapEstimateService(
            store: store,
            validator: defaultRegionalCareGapEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
