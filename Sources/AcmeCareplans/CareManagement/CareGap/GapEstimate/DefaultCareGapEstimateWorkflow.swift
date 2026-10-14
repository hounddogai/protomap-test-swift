import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves default care gap estimates through their life cycle and keeps a journal of what it did.
    final class DefaultCareGapEstimateService {
        var store: any DefaultCareGapEstimateStore
        var validator: DefaultCareGapEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultCareGapEstimateEngine

        init(store: any DefaultCareGapEstimateStore, validator: DefaultCareGapEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultCareGapEstimateEngine) {
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
                throw Kit.Failure("default care gap estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultCareGapEstimateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default care gap estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultCareGapEstimateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default care gap estimate \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newDefaultCareGapEstimateService(_ store: any DefaultCareGapEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultCareGapEstimateService {
        return DefaultCareGapEstimateService(
            store: store,
            validator: defaultDefaultCareGapEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultCareGapEstimateEngine(flags)
        )
    }
}
