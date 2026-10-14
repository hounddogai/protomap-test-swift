import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form targets through their life cycle and keeps a journal of what it did.
    final class ConsentFormTargetWorkflow {
        var store: any ConsentFormTargetStore
        var validator: ConsentFormTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ConsentFormTargetStore, validator: ConsentFormTargetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("consent form target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormTargetStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormTargetStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newConsentFormTargetWorkflow(_ store: any ConsentFormTargetStore, clock: any Kit.Clocks.Clock) -> ConsentFormTargetWorkflow {
        return ConsentFormTargetWorkflow(
            store: store,
            validator: defaultConsentFormTargetValidator(),
            clock: clock,
            journal: []
        )
    }
}
