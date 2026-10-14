import AcmePlatform
import Foundation

extension Labs {
    /// Moves pending specimen metrics through their life cycle and keeps a journal of what it did.
    final class PendingSpecimenMetricDesk {
        var store: any PendingSpecimenMetricStore
        var validator: PendingSpecimenMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingSpecimenMetricEngine

        init(store: any PendingSpecimenMetricStore, validator: PendingSpecimenMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingSpecimenMetricEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending specimen metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingSpecimenMetricStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending specimen metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingSpecimenMetricStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending specimen metric \(code) not found")
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

    static func newPendingSpecimenMetricDesk(_ store: any PendingSpecimenMetricStore, clock: any Kit.Clocks.Clock) -> PendingSpecimenMetricDesk {
        return PendingSpecimenMetricDesk(
            store: store,
            validator: defaultPendingSpecimenMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingSpecimenMetricEngine()
        )
    }
}
