import AcmePlatform
import Foundation

extension Staffing {
    /// Moves regional overtime plans through their life cycle and keeps a journal of what it did.
    final class RegionalOvertimePlanDesk {
        var store: any RegionalOvertimePlanStore
        var validator: RegionalOvertimePlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalOvertimePlanEngine

        init(store: any RegionalOvertimePlanStore, validator: RegionalOvertimePlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalOvertimePlanEngine) {
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
                throw Kit.Failure("regional overtime plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalOvertimePlanStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional overtime plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalOvertimePlanStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional overtime plan \(code) not found")
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

    static func newRegionalOvertimePlanDesk(_ store: any RegionalOvertimePlanStore, clock: any Kit.Clocks.Clock) -> RegionalOvertimePlanDesk {
        return RegionalOvertimePlanDesk(
            store: store,
            validator: defaultRegionalOvertimePlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalOvertimePlanEngine()
        )
    }
}
