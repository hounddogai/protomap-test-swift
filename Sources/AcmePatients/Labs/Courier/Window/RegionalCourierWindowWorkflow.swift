import AcmePlatform
import Foundation

extension Labs {
    /// Moves regional courier windows through their life cycle and keeps a journal of what it did.
    final class RegionalCourierWindowService {
        var store: any RegionalCourierWindowStore
        var validator: RegionalCourierWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalCourierWindowStore, validator: RegionalCourierWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional courier window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalCourierWindowStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional courier window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalCourierWindowStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newRegionalCourierWindowService(_ store: any RegionalCourierWindowStore, clock: any Kit.Clocks.Clock) -> RegionalCourierWindowService {
        return RegionalCourierWindowService(
            store: store,
            validator: defaultRegionalCourierWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
