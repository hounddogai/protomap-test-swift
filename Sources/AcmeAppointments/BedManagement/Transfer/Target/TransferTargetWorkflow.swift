import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves transfer targets through their life cycle and keeps a journal of what it did.
    final class TransferTargetCoordinator {
        var store: any TransferTargetStore
        var validator: TransferTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TransferTargetEngine

        init(store: any TransferTargetStore, validator: TransferTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TransferTargetEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TransferTargetStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TransferTargetStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer target \(code) not found")
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

    static func newTransferTargetCoordinator(_ store: any TransferTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TransferTargetCoordinator {
        return TransferTargetCoordinator(
            store: store,
            validator: defaultTransferTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultTransferTargetEngine(flags)
        )
    }
}
