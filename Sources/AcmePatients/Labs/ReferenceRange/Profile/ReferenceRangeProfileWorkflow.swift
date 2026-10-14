import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range profiles through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeProfileWorkflow {
        var store: any ReferenceRangeProfileStore
        var validator: ReferenceRangeProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferenceRangeProfileEngine

        init(store: any ReferenceRangeProfileStore, validator: ReferenceRangeProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferenceRangeProfileEngine) {
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
                throw Kit.Failure("reference range profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeProfileStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeProfileStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range profile \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newReferenceRangeProfileWorkflow(_ store: any ReferenceRangeProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ReferenceRangeProfileWorkflow {
        return ReferenceRangeProfileWorkflow(
            store: store,
            validator: defaultReferenceRangeProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferenceRangeProfileEngine(flags)
        )
    }
}
