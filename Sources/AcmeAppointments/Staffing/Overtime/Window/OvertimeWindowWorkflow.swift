import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime windows through their life cycle and keeps a journal of what it did.
    final class OvertimeWindowDesk {
        var store: any OvertimeWindowStore
        var validator: OvertimeWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OvertimeWindowEngine

        init(store: any OvertimeWindowStore, validator: OvertimeWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OvertimeWindowEngine) {
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
                throw Kit.Failure("overtime window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeWindowStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeWindowStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime window \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newOvertimeWindowDesk(_ store: any OvertimeWindowStore, clock: any Kit.Clocks.Clock) -> OvertimeWindowDesk {
        return OvertimeWindowDesk(
            store: store,
            validator: defaultOvertimeWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultOvertimeWindowEngine()
        )
    }
}
