import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime entries through their life cycle and keeps a journal of what it did.
    final class OvertimeEntryService {
        var store: any OvertimeEntryStore
        var validator: OvertimeEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OvertimeEntryEngine

        init(store: any OvertimeEntryStore, validator: OvertimeEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OvertimeEntryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeEntryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeEntryStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime entry \(code) not found")
            }
            let result = engine.run(item)
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

    static func newOvertimeEntryService(_ store: any OvertimeEntryStore, clock: any Kit.Clocks.Clock) -> OvertimeEntryService {
        return OvertimeEntryService(
            store: store,
            validator: defaultOvertimeEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultOvertimeEntryEngine()
        )
    }
}
