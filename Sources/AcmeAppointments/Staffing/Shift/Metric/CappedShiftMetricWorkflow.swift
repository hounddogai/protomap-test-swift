import AcmePlatform
import Foundation

extension Staffing {
    /// Moves capped shift metrics through their life cycle and keeps a journal of what it did.
    final class CappedShiftMetricService {
        var store: any CappedShiftMetricStore
        var validator: CappedShiftMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedShiftMetricEngine

        init(store: any CappedShiftMetricStore, validator: CappedShiftMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedShiftMetricEngine) {
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
                throw Kit.Failure("capped shift metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedShiftMetricStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped shift metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedShiftMetricStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped shift metric \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCappedShiftMetricService(_ store: any CappedShiftMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedShiftMetricService {
        return CappedShiftMetricService(
            store: store,
            validator: defaultCappedShiftMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedShiftMetricEngine(flags)
        )
    }
}
