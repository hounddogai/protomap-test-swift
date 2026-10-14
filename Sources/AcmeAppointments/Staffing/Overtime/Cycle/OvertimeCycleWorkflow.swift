import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime cycles through their life cycle and keeps a journal of what it did.
    final class OvertimeCycleService {
        var store: any OvertimeCycleStore
        var validator: OvertimeCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OvertimeCycleStore, validator: OvertimeCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeCycleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeCycleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newOvertimeCycleService(_ store: any OvertimeCycleStore, clock: any Kit.Clocks.Clock) -> OvertimeCycleService {
        return OvertimeCycleService(
            store: store,
            validator: defaultOvertimeCycleValidator(),
            clock: clock,
            journal: []
        )
    }
}
