import AcmePlatform
import Foundation

extension Imaging {
    /// Moves pending care protocol exceptions through their life cycle and keeps a journal of what it did.
    final class PendingCareProtocolExceptionDesk {
        var store: any PendingCareProtocolExceptionStore
        var validator: PendingCareProtocolExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingCareProtocolExceptionEngine

        init(store: any PendingCareProtocolExceptionStore, validator: PendingCareProtocolExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingCareProtocolExceptionEngine) {
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
                throw Kit.Failure("pending care protocol exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingCareProtocolExceptionStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending care protocol exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingCareProtocolExceptionStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending care protocol exception \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newPendingCareProtocolExceptionDesk(_ store: any PendingCareProtocolExceptionStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingCareProtocolExceptionDesk {
        return PendingCareProtocolExceptionDesk(
            store: store,
            validator: defaultPendingCareProtocolExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingCareProtocolExceptionEngine(flags)
        )
    }
}
