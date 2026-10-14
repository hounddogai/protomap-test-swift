import AcmePlatform
import Foundation

extension Consent {
    /// Moves pending disclosure windows through their life cycle and keeps a journal of what it did.
    final class PendingDisclosureWindowManager {
        var store: any PendingDisclosureWindowStore
        var validator: PendingDisclosureWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingDisclosureWindowEngine

        init(store: any PendingDisclosureWindowStore, validator: PendingDisclosureWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingDisclosureWindowEngine) {
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
                throw Kit.Failure("pending disclosure window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingDisclosureWindowStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending disclosure window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingDisclosureWindowStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending disclosure window \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newPendingDisclosureWindowManager(_ store: any PendingDisclosureWindowStore, clock: any Kit.Clocks.Clock) -> PendingDisclosureWindowManager {
        return PendingDisclosureWindowManager(
            store: store,
            validator: defaultPendingDisclosureWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingDisclosureWindowEngine()
        )
    }
}
