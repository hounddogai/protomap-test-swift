import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form checkpoints through their life cycle and keeps a journal of what it did.
    final class ConsentFormCheckpointCoordinator {
        var store: any ConsentFormCheckpointStore
        var validator: ConsentFormCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormCheckpointEngine

        init(store: any ConsentFormCheckpointStore, validator: ConsentFormCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormCheckpointEngine) {
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
                throw Kit.Failure("consent form checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormCheckpointStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormCheckpointStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form checkpoint \(code) not found")
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

    static func newConsentFormCheckpointCoordinator(_ store: any ConsentFormCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ConsentFormCheckpointCoordinator {
        return ConsentFormCheckpointCoordinator(
            store: store,
            validator: defaultConsentFormCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormCheckpointEngine(flags)
        )
    }
}
