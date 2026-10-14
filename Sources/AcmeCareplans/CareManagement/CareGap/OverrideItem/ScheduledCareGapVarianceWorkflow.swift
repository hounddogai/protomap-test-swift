import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves scheduled care gap variances through their life cycle and keeps a journal of what it did.
    final class ScheduledCareGapVarianceService {
        var store: any ScheduledCareGapVarianceStore
        var validator: ScheduledCareGapVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledCareGapVarianceEngine

        init(store: any ScheduledCareGapVarianceStore, validator: ScheduledCareGapVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledCareGapVarianceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care gap variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledCareGapVarianceStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care gap variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledCareGapVarianceStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care gap variance \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newScheduledCareGapVarianceService(_ store: any ScheduledCareGapVarianceStore, clock: any Kit.Clocks.Clock) -> ScheduledCareGapVarianceService {
        return ScheduledCareGapVarianceService(
            store: store,
            validator: defaultScheduledCareGapVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledCareGapVarianceEngine()
        )
    }
}
