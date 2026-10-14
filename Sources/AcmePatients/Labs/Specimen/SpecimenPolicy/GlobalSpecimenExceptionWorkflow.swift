import AcmePlatform
import Foundation

extension Labs {
    /// Moves global specimen exceptions through their life cycle and keeps a journal of what it did.
    final class GlobalSpecimenExceptionWorkflow {
        var store: any GlobalSpecimenExceptionStore
        var validator: GlobalSpecimenExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalSpecimenExceptionEngine

        init(store: any GlobalSpecimenExceptionStore, validator: GlobalSpecimenExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalSpecimenExceptionEngine) {
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
                throw Kit.Failure("global specimen exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalSpecimenExceptionStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global specimen exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalSpecimenExceptionStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global specimen exception \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newGlobalSpecimenExceptionWorkflow(_ store: any GlobalSpecimenExceptionStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalSpecimenExceptionWorkflow {
        return GlobalSpecimenExceptionWorkflow(
            store: store,
            validator: defaultGlobalSpecimenExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalSpecimenExceptionEngine(flags)
        )
    }
}
