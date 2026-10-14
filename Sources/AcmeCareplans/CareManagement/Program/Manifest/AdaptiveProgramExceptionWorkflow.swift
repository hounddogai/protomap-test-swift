import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves adaptive program exceptions through their life cycle and keeps a journal of what it did.
    final class AdaptiveProgramExceptionCoordinator {
        var store: any AdaptiveProgramExceptionStore
        var validator: AdaptiveProgramExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveProgramExceptionEngine

        init(store: any AdaptiveProgramExceptionStore, validator: AdaptiveProgramExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveProgramExceptionEngine) {
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
                throw Kit.Failure("adaptive program exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveProgramExceptionStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive program exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveProgramExceptionStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive program exception \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newAdaptiveProgramExceptionCoordinator(_ store: any AdaptiveProgramExceptionStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveProgramExceptionCoordinator {
        return AdaptiveProgramExceptionCoordinator(
            store: store,
            validator: defaultAdaptiveProgramExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveProgramExceptionEngine(flags)
        )
    }
}
