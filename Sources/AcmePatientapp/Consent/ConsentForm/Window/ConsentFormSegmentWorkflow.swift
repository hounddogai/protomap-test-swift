import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form segments through their life cycle and keeps a journal of what it did.
    final class ConsentFormSegmentWorkflow {
        var store: any ConsentFormSegmentStore
        var validator: ConsentFormSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormSegmentEngine

        init(store: any ConsentFormSegmentStore, validator: ConsentFormSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormSegmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormSegmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormSegmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form segment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newConsentFormSegmentWorkflow(_ store: any ConsentFormSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ConsentFormSegmentWorkflow {
        return ConsentFormSegmentWorkflow(
            store: store,
            validator: defaultConsentFormSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormSegmentEngine(flags)
        )
    }
}
